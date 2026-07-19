import { Module, ValidationPipe } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { GlobalExceptionFilter } from './common/filters/global-exception.filter';
import { RolesGuard } from './common/guards/roles.guard';
import { SupabaseAuthGuard } from './common/guards/supabase-auth.guard';
import { ResponseEnvelopeInterceptor } from './common/interceptors/response-envelope.interceptor';
import { AppConfigModule } from './config/app-config.module';
import { SupabaseModule } from './integrations/supabase/supabase.module';
import { AssistantModule } from './modules/assistant/assistant.module';
import { CollaborationModule } from './modules/collaboration/collaboration.module';
import { CommunityModule } from './modules/community/community.module';
import { ComplaintsModule } from './modules/complaints/complaints.module';
import { EmergencyModule } from './modules/emergency/emergency.module';
import { FamilyModule } from './modules/family/family.module';
import { GovernmentModule } from './modules/government/government.module';
import { IncidentsModule } from './modules/incidents/incidents.module';
import { RoutingModule } from './modules/routing/routing.module';
import { SafetyModule } from './modules/safety/safety.module';
import { TransportsModule } from './modules/transports/transports.module';
import { TripsModule } from './modules/trips/trips.module';
import { UsersModule } from './modules/users/users.module';

@Module({
  imports: [
    AppConfigModule,
    SupabaseModule,
    ScheduleModule.forRoot(),
    UsersModule,
    TransportsModule,
    RoutingModule,
    TripsModule,
    CollaborationModule,
    CommunityModule,
    EmergencyModule,
    IncidentsModule,
    ComplaintsModule,
    FamilyModule,
    SafetyModule,
    AssistantModule,
    GovernmentModule,
  ],
  controllers: [AppController],
  providers: [
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
        transformOptions: { enableImplicitConversion: false },
      }),
    },
    { provide: APP_GUARD, useClass: SupabaseAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    { provide: APP_INTERCEPTOR, useClass: ResponseEnvelopeInterceptor },
    { provide: APP_FILTER, useClass: GlobalExceptionFilter },
  ],
})
export class AppModule {}
