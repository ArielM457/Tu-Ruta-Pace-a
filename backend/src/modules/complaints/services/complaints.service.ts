import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import {
  ComplaintStatus,
  ComplaintTransportKind,
} from '../../../common/types/domain';
import { TransportsService } from '../../transports/services/transports.service';
import { CreateComplaintDto } from '../dto/create-complaint.dto';
import {
  ComplaintRecord,
  ComplaintsRepository,
} from '../repositories/complaints.repository';

export interface Complaint {
  id: string;
  vehicleIdentifier: string | null;
  transportKind: ComplaintTransportKind;
  lineId: string | null;
  stopId: string | null;
  complaint: string;
  status: ComplaintStatus;
  createdAt: string;
}

@Injectable()
export class ComplaintsService {
  constructor(
    private readonly complaintsRepository: ComplaintsRepository,
    private readonly transportsService: TransportsService,
  ) {}

  async createComplaint(
    userId: string,
    dto: CreateComplaintDto,
  ): Promise<Complaint> {
    this.assertVehicleOrLinePresent(dto);
    await this.assertLineAndStopAreValid(dto);
    const record = await this.complaintsRepository.create({
      user_id: userId,
      vehicle_identifier: dto.vehicleIdentifier ?? null,
      transport_kind: dto.transportKind,
      line_id: dto.lineId ?? null,
      stop_id: dto.stopId ?? null,
      complaint: dto.complaint,
    });
    return this.toComplaint(record);
  }

  async getMyComplaints(userId: string): Promise<Complaint[]> {
    const records = await this.complaintsRepository.findByUser(userId);
    return records.map((record) => this.toComplaint(record));
  }

  private assertVehicleOrLinePresent(dto: CreateComplaintDto): void {
    if (!dto.vehicleIdentifier && !dto.lineId) {
      throw new DomainException(
        'VEHICLE_OR_LINE_REQUIRED',
        'Indica la placa o número del vehículo, o la línea del transporte',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  private async assertLineAndStopAreValid(
    dto: CreateComplaintDto,
  ): Promise<void> {
    if (dto.stopId && !dto.lineId) {
      throw new DomainException(
        'STOP_REQUIRES_LINE',
        'Para indicar una parada primero indica la línea a la que pertenece',
        HttpStatus.BAD_REQUEST,
      );
    }
    if (!dto.lineId) {
      return;
    }
    const stops = await this.transportsService.listLineStops(dto.lineId);
    if (dto.stopId && !stops.some((stop) => stop.id === dto.stopId)) {
      throw new DomainException(
        'STOP_NOT_IN_LINE',
        'La parada indicada no pertenece a esa línea',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  private toComplaint(record: ComplaintRecord): Complaint {
    return {
      id: record.id,
      vehicleIdentifier: record.vehicle_identifier,
      transportKind: record.transport_kind as ComplaintTransportKind,
      lineId: record.line_id,
      stopId: record.stop_id,
      complaint: record.complaint,
      status: record.status as ComplaintStatus,
      createdAt: record.created_at,
    };
  }
}
