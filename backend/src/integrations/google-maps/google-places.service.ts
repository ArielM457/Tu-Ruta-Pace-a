import { HttpService } from '@nestjs/axios';
import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { firstValueFrom } from 'rxjs';
import { AppConfigService } from '../../config/app-config.service';

export interface PlaceSuggestion {
  description: string;
  placeId: string;
  lat: number;
  lng: number;
}

interface AutocompleteApiResponse {
  predictions?: Array<{ description: string; place_id: string }>;
}

interface PlaceDetailsApiResponse {
  result?: { geometry?: { location?: { lat: number; lng: number } } };
}

const AUTOCOMPLETE_API_URL =
  'https://maps.googleapis.com/maps/api/place/autocomplete/json';
const DETAILS_API_URL = 'https://maps.googleapis.com/maps/api/place/details/json';
const LA_PAZ_CENTER = { lat: -16.5, lng: -68.15 };
const LA_PAZ_BIAS_RADIUS_METERS = 30000;
const MAXIMUM_SUGGESTIONS = 5;

@Injectable()
export class GooglePlacesService {
  private readonly logger = new Logger(GooglePlacesService.name);

  constructor(
    private readonly httpService: HttpService,
    private readonly appConfig: AppConfigService,
  ) {}

  async autocomplete(query: string): Promise<PlaceSuggestion[]> {
    const apiKey = this.appConfig.googleMapsApiKey;
    if (!apiKey) {
      return [];
    }

    const sessionToken = randomUUID();
    const predictions = await this.fetchPredictions(query, apiKey, sessionToken);
    if (predictions.length === 0) {
      return [];
    }

    const suggestions = await Promise.all(
      predictions
        .slice(0, MAXIMUM_SUGGESTIONS)
        .map((prediction) =>
          this.fetchPlaceLocation(prediction, apiKey, sessionToken),
        ),
    );
    return suggestions.filter((suggestion): suggestion is PlaceSuggestion =>
      Boolean(suggestion),
    );
  }

  private async fetchPredictions(
    query: string,
    apiKey: string,
    sessionToken: string,
  ): Promise<Array<{ description: string; place_id: string }>> {
    try {
      const response = await firstValueFrom(
        this.httpService.get<AutocompleteApiResponse>(AUTOCOMPLETE_API_URL, {
          params: {
            input: query,
            location: `${LA_PAZ_CENTER.lat},${LA_PAZ_CENTER.lng}`,
            radius: LA_PAZ_BIAS_RADIUS_METERS,
            language: 'es',
            components: 'country:bo',
            sessiontoken: sessionToken,
            key: apiKey,
          },
        }),
      );
      return response.data.predictions ?? [];
    } catch (error) {
      this.logger.warn(
        `Google Places Autocomplete falló: ${(error as Error).message}`,
      );
      return [];
    }
  }

  private async fetchPlaceLocation(
    prediction: { description: string; place_id: string },
    apiKey: string,
    sessionToken: string,
  ): Promise<PlaceSuggestion | null> {
    try {
      const response = await firstValueFrom(
        this.httpService.get<PlaceDetailsApiResponse>(DETAILS_API_URL, {
          params: {
            place_id: prediction.place_id,
            fields: 'geometry',
            sessiontoken: sessionToken,
            key: apiKey,
          },
        }),
      );
      const location = response.data.result?.geometry?.location;
      if (!location) {
        return null;
      }
      return {
        description: prediction.description,
        placeId: prediction.place_id,
        lat: location.lat,
        lng: location.lng,
      };
    } catch (error) {
      this.logger.warn(
        `Google Places Details falló para ${prediction.place_id}: ${(error as Error).message}`,
      );
      return null;
    }
  }
}
