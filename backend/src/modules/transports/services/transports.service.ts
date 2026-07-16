import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import { TransportKind } from '../../../common/types/domain';
import {
  LineWithStopsRecord,
  TransportLineRecord,
  TransportLinesRepository,
  TransportStopRecord,
} from '../repositories/transport-lines.repository';

export interface TransportStop {
  id: string;
  name: string;
  lat: number;
  lng: number;
  sequence: number;
  isAccessible: boolean;
}

export interface TransportLine {
  id: string;
  kind: TransportKind;
  name: string;
  color: string | null;
  fareBs: number;
  serviceStart: string | null;
  serviceEnd: string | null;
}

export interface NetworkLine extends TransportLine {
  stops: TransportStop[];
}

const ROUTABLE_NETWORK_KINDS = [
  TransportKind.CableCar,
  TransportKind.Pumakatari,
];

@Injectable()
export class TransportsService {
  constructor(
    private readonly transportLinesRepository: TransportLinesRepository,
  ) {}

  async listLines(): Promise<TransportLine[]> {
    const lines = await this.transportLinesRepository.findActiveLines();
    return lines.map((line) => this.toLine(line));
  }

  async listLineStops(lineId: string): Promise<TransportStop[]> {
    const line = await this.transportLinesRepository.findLineById(lineId);
    if (!line) {
      throw new DomainException(
        'LINE_NOT_FOUND',
        'La línea de transporte no existe',
        HttpStatus.NOT_FOUND,
      );
    }
    const stops = await this.transportLinesRepository.findStopsByLine(lineId);
    return stops.map((stop) => this.toStop(stop));
  }

  async getLine(lineId: string): Promise<TransportLine> {
    const line = await this.transportLinesRepository.findLineById(lineId);
    if (!line) {
      throw new DomainException(
        'LINE_NOT_FOUND',
        'La línea de transporte no existe',
        HttpStatus.NOT_FOUND,
      );
    }
    return this.toLine(line);
  }

  async getStop(stopId: string): Promise<TransportStop> {
    const stop = await this.transportLinesRepository.findStopById(stopId);
    if (!stop) {
      throw new DomainException(
        'STOP_NOT_FOUND',
        'La parada indicada no existe',
        HttpStatus.NOT_FOUND,
      );
    }
    return this.toStop(stop);
  }

  async getRoutableNetwork(): Promise<NetworkLine[]> {
    const lines = await this.transportLinesRepository.findActiveLinesWithStops(
      ROUTABLE_NETWORK_KINDS,
    );
    return lines
      .filter((line) => line.transport_stops.length >= 2)
      .map((line) => this.toNetworkLine(line));
  }

  isLineInService(line: TransportLine, at: Date): boolean {
    if (!line.serviceStart || !line.serviceEnd) {
      return true;
    }
    const minutesOfDay = at.getHours() * 60 + at.getMinutes();
    const start = this.parseTimeToMinutes(line.serviceStart);
    const end = this.parseTimeToMinutes(line.serviceEnd);
    if (start <= end) {
      return minutesOfDay >= start && minutesOfDay <= end;
    }
    return minutesOfDay >= start || minutesOfDay <= end;
  }

  private parseTimeToMinutes(time: string): number {
    const [hours, minutes] = time.split(':').map(Number);
    return hours * 60 + (minutes || 0);
  }

  private toLine(record: TransportLineRecord): TransportLine {
    return {
      id: record.id,
      kind: record.kind as TransportKind,
      name: record.name,
      color: record.color,
      fareBs: Number(record.fare_bs),
      serviceStart: record.service_start,
      serviceEnd: record.service_end,
    };
  }

  private toStop(record: TransportStopRecord): TransportStop {
    return {
      id: record.id,
      name: record.name,
      lat: Number(record.lat),
      lng: Number(record.lng),
      sequence: record.sequence,
      isAccessible: record.is_accessible,
    };
  }

  private toNetworkLine(record: LineWithStopsRecord): NetworkLine {
    return {
      ...this.toLine(record),
      stops: record.transport_stops
        .map((stop) => this.toStop(stop))
        .sort((a, b) => a.sequence - b.sequence),
    };
  }
}
