import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import {
  ComplaintStatus,
  ComplaintTransportKind,
  ComplaintType,
} from '../../../common/types/domain';
import { TransportsService } from '../../transports/services/transports.service';
import { CreateComplaintDto } from '../dto/create-complaint.dto';
import {
  ComplaintRecord,
  ComplaintsRepository,
} from '../repositories/complaints.repository';

export interface Complaint {
  id: string;
  type: ComplaintType;
  vehicleIdentifier: string | null;
  transportKind: ComplaintTransportKind;
  routeLabel: string | null;
  lineId: string | null;
  stopId: string | null;
  complaint: string;
  photoUrl: string | null;
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
      complaint_type: dto.type,
      vehicle_identifier: dto.vehicleIdentifier ?? null,
      transport_kind: dto.transportKind ?? ComplaintTransportKind.Minibus,
      route_label: dto.routeLabel ?? null,
      line_id: dto.lineId ?? null,
      stop_id: dto.stopId ?? null,
      complaint: dto.complaint,
      photo_url: dto.photoUrl ?? null,
    });
    return this.toComplaint(record);
  }

  async getMyComplaints(userId: string): Promise<Complaint[]> {
    const records = await this.complaintsRepository.findByUser(userId);
    return records.map((record) => this.toComplaint(record));
  }

  private assertVehicleOrLinePresent(dto: CreateComplaintDto): void {
    if (!dto.vehicleIdentifier && !dto.lineId && !dto.routeLabel) {
      throw new DomainException(
        'VEHICLE_OR_LINE_REQUIRED',
        'Indica la placa o conductor, la ruta/línea, o selecciona una línea registrada',
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
      type: record.complaint_type as ComplaintType,
      vehicleIdentifier: record.vehicle_identifier,
      transportKind: record.transport_kind as ComplaintTransportKind,
      routeLabel: record.route_label,
      lineId: record.line_id,
      stopId: record.stop_id,
      complaint: record.complaint,
      photoUrl: record.photo_url,
      status: record.status as ComplaintStatus,
      createdAt: record.created_at,
    };
  }
}
