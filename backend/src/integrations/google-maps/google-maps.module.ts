import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { GoogleDirectionsService } from './google-directions.service';

@Module({
  imports: [HttpModule],
  providers: [GoogleDirectionsService],
  exports: [GoogleDirectionsService],
})
export class GoogleMapsModule {}
