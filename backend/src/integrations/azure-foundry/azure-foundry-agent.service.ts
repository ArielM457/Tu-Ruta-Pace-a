import { HttpService } from '@nestjs/axios';
import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { firstValueFrom } from 'rxjs';
import { DomainException } from '../../common/exceptions/domain.exception';
import { AppConfigService } from '../../config/app-config.service';

export interface AgentChatReply {
  reply: string;
  isCommunityEstimate: boolean;
}

export interface AgentVoiceRouteReply {
  confirmedDestination: string | null;
  spokenReply: string;
}

interface FoundryRun {
  id: string;
  thread_id: string;
  status: string;
  last_error?: { message?: string } | null;
}

interface FoundryMessageList {
  data: Array<{
    role: string;
    content: Array<{ type: string; text?: { value: string } }>;
  }>;
}

const COMMUNITY_MARKER = '[COMUNIDAD]';
const RUN_POLL_INTERVAL_MILLISECONDS = 1000;
const RUN_POLL_MAXIMUM_ATTEMPTS = 30;

@Injectable()
export class AzureFoundryAgentService {
  private readonly logger = new Logger(AzureFoundryAgentService.name);

  constructor(
    private readonly httpService: HttpService,
    private readonly appConfig: AppConfigService,
  ) {}

  async sendChat(
    message: string,
    context: Record<string, unknown>,
  ): Promise<AgentChatReply> {
    const prompt = [
      'Eres el asistente de movilidad de Ayni Ruta en La Paz, Bolivia. Responde en español, breve y accionable.',
      `Si tu respuesta se basa en las experiencias de la comunidad incluidas en el contexto, comienza tu respuesta exactamente con ${COMMUNITY_MARKER}.`,
      '',
      `Mensaje del usuario: ${message}`,
      '',
      '[CONTEXTO DE LA CIUDAD]',
      JSON.stringify(context),
    ].join('\n');
    const rawReply = await this.askAgent(prompt);
    const isCommunityEstimate = rawReply.startsWith(COMMUNITY_MARKER);
    const reply = isCommunityEstimate
      ? rawReply.slice(COMMUNITY_MARKER.length).trim()
      : rawReply;
    return { reply, isCommunityEstimate };
  }

  async requestVoiceRoute(
    transcript: string,
    context: Record<string, unknown>,
  ): Promise<AgentVoiceRouteReply> {
    const prompt = [
      'Eres el asistente de voz de Ayni Ruta en La Paz, Bolivia.',
      'Interpreta el destino que pide esta transcripción de voz y responde SOLO un JSON con este formato exacto:',
      '{"confirmedDestination": "<nombre del destino entendido o null>", "spokenReply": "<confirmación hablada en español, corta y clara>"}',
      '',
      `Transcripción: ${transcript}`,
      '',
      '[CONTEXTO DE LA CIUDAD]',
      JSON.stringify(context),
    ].join('\n');
    const rawReply = await this.askAgent(prompt);
    return this.parseVoiceRouteReply(rawReply);
  }

  private async askAgent(content: string): Promise<string> {
    const run = await this.createThreadAndRun(content);
    const finishedRun = await this.waitForRunCompletion(run);
    if (finishedRun.status !== 'completed') {
      this.logger.warn(
        `Run del agente terminó en estado ${finishedRun.status}: ${finishedRun.last_error?.message ?? 'sin detalle'}`,
      );
      throw this.unavailable();
    }
    return this.readLatestAssistantMessage(finishedRun.thread_id);
  }

  private async createThreadAndRun(content: string): Promise<FoundryRun> {
    try {
      const response = await firstValueFrom(
        this.httpService.post<FoundryRun>(
          this.buildUrl('/threads/runs'),
          {
            assistant_id: this.requireConfig(
              this.appConfig.azureFoundryAgentId,
            ),
            thread: { messages: [{ role: 'user', content }] },
          },
          { headers: this.buildHeaders(), params: this.buildParams() },
        ),
      );
      return response.data;
    } catch (error) {
      this.logger.warn(
        `No se pudo iniciar el run del agente: ${(error as Error).message}`,
      );
      throw this.unavailable();
    }
  }

  private async waitForRunCompletion(run: FoundryRun): Promise<FoundryRun> {
    let currentRun = run;
    for (
      let attempt = 0;
      attempt < RUN_POLL_MAXIMUM_ATTEMPTS &&
      ['queued', 'in_progress'].includes(currentRun.status);
      attempt += 1
    ) {
      await this.sleep(RUN_POLL_INTERVAL_MILLISECONDS);
      currentRun = await this.fetchRun(currentRun.thread_id, currentRun.id);
    }
    return currentRun;
  }

  private async fetchRun(threadId: string, runId: string): Promise<FoundryRun> {
    try {
      const response = await firstValueFrom(
        this.httpService.get<FoundryRun>(
          this.buildUrl(`/threads/${threadId}/runs/${runId}`),
          { headers: this.buildHeaders(), params: this.buildParams() },
        ),
      );
      return response.data;
    } catch (error) {
      this.logger.warn(
        `No se pudo consultar el run del agente: ${(error as Error).message}`,
      );
      throw this.unavailable();
    }
  }

  private async readLatestAssistantMessage(threadId: string): Promise<string> {
    try {
      const response = await firstValueFrom(
        this.httpService.get<FoundryMessageList>(
          this.buildUrl(`/threads/${threadId}/messages`),
          {
            headers: this.buildHeaders(),
            params: { ...this.buildParams(), order: 'desc', limit: 5 },
          },
        ),
      );
      const assistantMessage = response.data.data.find(
        (message) => message.role === 'assistant',
      );
      const textBlock = assistantMessage?.content.find(
        (block) => block.type === 'text' && block.text?.value,
      );
      if (!textBlock?.text?.value) {
        throw new Error('el agente no devolvió texto');
      }
      return textBlock.text.value.trim();
    } catch (error) {
      this.logger.warn(
        `No se pudo leer la respuesta del agente: ${(error as Error).message}`,
      );
      throw this.unavailable();
    }
  }

  private parseVoiceRouteReply(rawReply: string): AgentVoiceRouteReply {
    const jsonMatch = rawReply.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      try {
        const parsed = JSON.parse(jsonMatch[0]) as {
          confirmedDestination?: unknown;
          spokenReply?: unknown;
        };
        return {
          confirmedDestination:
            typeof parsed.confirmedDestination === 'string'
              ? parsed.confirmedDestination
              : null,
          spokenReply:
            typeof parsed.spokenReply === 'string'
              ? parsed.spokenReply
              : rawReply,
        };
      } catch {
        return { confirmedDestination: null, spokenReply: rawReply };
      }
    }
    return { confirmedDestination: null, spokenReply: rawReply };
  }

  private buildUrl(path: string): string {
    const endpoint = this.requireConfig(this.appConfig.azureFoundryEndpoint);
    return `${endpoint.replace(/\/$/, '')}${path}`;
  }

  private buildParams(): Record<string, string> {
    return { 'api-version': this.appConfig.azureFoundryApiVersion };
  }

  private buildHeaders(): Record<string, string> {
    const apiKey = this.requireConfig(this.appConfig.azureFoundryApiKey);
    return { 'api-key': apiKey, Authorization: `Bearer ${apiKey}` };
  }

  private requireConfig(value: string | null): string {
    if (!value) {
      throw new DomainException(
        'AI_AGENT_NOT_CONFIGURED',
        'El agente de Azure AI Foundry aún no está configurado',
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }
    return value;
  }

  private unavailable(): DomainException {
    return new DomainException(
      'AI_AGENT_UNAVAILABLE',
      'El agente de IA no respondió, intenta de nuevo en unos minutos',
      HttpStatus.BAD_GATEWAY,
    );
  }

  private sleep(milliseconds: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, milliseconds));
  }
}
