import { Body, Controller, Get, Post } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { CreateComplaintDto } from '../dto/create-complaint.dto';
import { Complaint, ComplaintsService } from '../services/complaints.service';

@Controller('complaints')
export class ComplaintsController {
  constructor(private readonly complaintsService: ComplaintsService) {}

  @Post()
  createComplaint(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateComplaintDto,
  ): Promise<Complaint> {
    return this.complaintsService.createComplaint(user.userId, dto);
  }

  @Get('mine')
  getMyComplaints(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<Complaint[]> {
    return this.complaintsService.getMyComplaints(user.userId);
  }
}
