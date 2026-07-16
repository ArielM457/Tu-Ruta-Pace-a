import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { AzureFoundryAgentService } from './azure-foundry-agent.service';

@Module({
  imports: [HttpModule],
  providers: [AzureFoundryAgentService],
  exports: [AzureFoundryAgentService],
})
export class AzureFoundryModule {}
