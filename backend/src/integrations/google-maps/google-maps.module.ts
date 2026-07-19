import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { GoogleDirectionsService } from './google-directions.service';
import { GooglePlacesService } from './google-places.service';

@Module({
  imports: [HttpModule],
  providers: [GoogleDirectionsService, GooglePlacesService],
  exports: [GoogleDirectionsService, GooglePlacesService],
})
export class GoogleMapsModule {}
