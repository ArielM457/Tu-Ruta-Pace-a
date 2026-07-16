import { Controller, Get, Param, ParseUUIDPipe } from '@nestjs/common';
import {
  TransportLine,
  TransportsService,
  TransportStop,
} from '../services/transports.service';

@Controller('transports')
export class TransportsController {
  constructor(private readonly transportsService: TransportsService) {}

  @Get('lines')
  listLines(): Promise<TransportLine[]> {
    return this.transportsService.listLines();
  }

  @Get('lines/:id/stops')
  listLineStops(
    @Param('id', ParseUUIDPipe) lineId: string,
  ): Promise<TransportStop[]> {
    return this.transportsService.listLineStops(lineId);
  }
}
