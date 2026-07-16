import { Injectable } from '@nestjs/common';
import {
  AgentChatReply,
  AgentVoiceRouteReply,
  AzureFoundryAgentService,
} from '../../../integrations/azure-foundry/azure-foundry-agent.service';
import { ChatRequestDto } from '../dto/chat-request.dto';
import { VoiceRouteRequestDto } from '../dto/voice-route-request.dto';
import { AssistantContextService } from './assistant-context.service';

@Injectable()
export class AssistantService {
  constructor(
    private readonly azureFoundryAgentService: AzureFoundryAgentService,
    private readonly assistantContextService: AssistantContextService,
  ) {}

  async chat(userId: string, dto: ChatRequestDto): Promise<AgentChatReply> {
    const context = await this.assistantContextService.buildContext(
      userId,
      dto.tripId,
      dto.location,
    );
    return this.azureFoundryAgentService.sendChat(dto.message, context);
  }

  async voiceRoute(
    userId: string,
    dto: VoiceRouteRequestDto,
  ): Promise<AgentVoiceRouteReply> {
    const context = await this.assistantContextService.buildContext(
      userId,
      undefined,
      dto.location,
    );
    return this.azureFoundryAgentService.requestVoiceRoute(
      dto.transcript,
      context,
    );
  }
}
