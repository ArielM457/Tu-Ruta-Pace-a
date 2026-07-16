import { Body, Controller, Post } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import {
  AgentChatReply,
  AgentVoiceRouteReply,
} from '../../../integrations/azure-foundry/azure-foundry-agent.service';
import { ChatRequestDto } from '../dto/chat-request.dto';
import { VoiceRouteRequestDto } from '../dto/voice-route-request.dto';
import { AssistantService } from '../services/assistant.service';

@Controller('assistant')
export class AssistantController {
  constructor(private readonly assistantService: AssistantService) {}

  @Post('chat')
  chat(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ChatRequestDto,
  ): Promise<AgentChatReply> {
    return this.assistantService.chat(user.userId, dto);
  }

  @Post('voice-route')
  voiceRoute(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: VoiceRouteRequestDto,
  ): Promise<AgentVoiceRouteReply> {
    return this.assistantService.voiceRoute(user.userId, dto);
  }
}
