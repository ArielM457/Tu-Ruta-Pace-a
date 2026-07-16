import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SupabaseService } from '../../integrations/supabase/supabase.service';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { DomainException } from '../exceptions/domain.exception';
import { AuthenticatedUser, UserRole } from '../types/domain';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly supabaseService: SupabaseService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }
    const request = context
      .switchToHttp()
      .getRequest<{ user?: AuthenticatedUser }>();
    const user = request.user;
    if (!user) {
      return false;
    }
    const role = await this.resolveRole(user.userId);
    request.user = { ...user, role };
    if (!requiredRoles.includes(role)) {
      throw new DomainException(
        'FORBIDDEN_ROLE',
        'No tienes permisos para esta operación',
        HttpStatus.FORBIDDEN,
      );
    }
    return true;
  }

  private async resolveRole(userId: string): Promise<UserRole> {
    const { data } = await this.supabaseService.client
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .maybeSingle();
    const role = (data as { role?: string } | null)?.role;
    return role === UserRole.Government
      ? UserRole.Government
      : UserRole.Citizen;
  }
}
