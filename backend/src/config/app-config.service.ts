import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AppConfigService {
  constructor(private readonly configService: ConfigService) {}

  get port(): number {
    return this.readNumber('PORT', 3000);
  }

  get corsOrigins(): string[] {
    const raw = this.configService.get<string>('CORS_ORIGINS') ?? '*';
    return raw.split(',').map((origin) => origin.trim());
  }

  get supabaseUrl(): string {
    return this.readRequired('SUPABASE_URL');
  }

  get supabaseServiceRoleKey(): string {
    return this.readRequired('SUPABASE_SERVICE_ROLE_KEY');
  }

  get supabaseJwtSecret(): string {
    return this.readRequired('SUPABASE_JWT_SECRET');
  }

  get googleMapsApiKey(): string | null {
    return this.configService.get<string>('GOOGLE_MAPS_API_KEY') || null;
  }

  get azureFoundryEndpoint(): string | null {
    return this.configService.get<string>('AZURE_FOUNDRY_ENDPOINT') || null;
  }

  get azureFoundryApiKey(): string | null {
    return this.configService.get<string>('AZURE_FOUNDRY_API_KEY') || null;
  }

  get azureFoundryAgentId(): string | null {
    return this.configService.get<string>('AZURE_FOUNDRY_AGENT_ID') || null;
  }

  get azureFoundryApiVersion(): string {
    return (
      this.configService.get<string>('AZURE_FOUNDRY_API_VERSION') ||
      '2025-05-01'
    );
  }

  get ayniRatePerMinute(): number {
    return this.readNumber('AYNI_RATE_PER_MINUTE', 1);
  }

  get ayniQueryCost(): number {
    return this.readNumber('AYNI_QUERY_COST', 5);
  }

  get ayniMaximumPointsPerShare(): number {
    return this.readNumber('AYNI_MAXIMUM_POINTS_PER_SHARE', 60);
  }

  get ayniQuestionCost(): number {
    return this.readNumber('AYNI_QUESTION_COST', 5);
  }

  get ayniQuestionTimeoutMinutes(): number {
    return this.readNumber('AYNI_QUESTION_TIMEOUT_MINUTES', 10);
  }

  get ayniVerifiedReportReward(): number {
    return this.readNumber('AYNI_VERIFIED_REPORT_REWARD', 10);
  }

  get incidentConfirmThreshold(): number {
    return this.readNumber('INCIDENT_CONFIRM_THRESHOLD', 3);
  }

  get incidentResolveThreshold(): number {
    return this.readNumber('INCIDENT_RESOLVE_THRESHOLD', 3);
  }

  private readRequired(key: string): string {
    const value = this.configService.get<string>(key);
    if (!value) {
      throw new Error(`Falta la variable de entorno requerida ${key}`);
    }
    return value;
  }

  private readNumber(key: string, fallback: number): number {
    const raw = this.configService.get<string>(key);
    if (!raw) {
      return fallback;
    }
    const parsed = Number(raw);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
}
