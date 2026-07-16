import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { JwtPayload, verify } from 'jsonwebtoken';
import { AppConfigService } from '../../config/app-config.service';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { DomainException } from '../exceptions/domain.exception';
import { AuthenticatedUser, UserRole } from '../types/domain';

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly appConfig: AppConfigService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }
    const request = context
      .switchToHttp()
      .getRequest<Request & { user?: AuthenticatedUser }>();
    const token = this.extractBearerToken(request);
    if (!token) {
      throw new DomainException(
        'MISSING_TOKEN',
        'Se requiere un token de autenticación',
        HttpStatus.UNAUTHORIZED,
      );
    }
    request.user = this.verifyToken(token);
    return true;
  }

  private extractBearerToken(request: Request): string | null {
    const header = request.headers.authorization;
    if (!header) {
      return null;
    }
    const [scheme, token] = header.split(' ');
    return scheme?.toLowerCase() === 'bearer' && token ? token : null;
  }

  private verifyToken(token: string): AuthenticatedUser {
    try {
      const payload = verify(
        token,
        this.appConfig.supabaseJwtSecret,
      ) as JwtPayload;
      if (!payload.sub) {
        throw new Error('missing subject');
      }
      return { userId: payload.sub, role: UserRole.Citizen };
    } catch {
      throw new DomainException(
        'INVALID_TOKEN',
        'El token de autenticación no es válido o expiró',
        HttpStatus.UNAUTHORIZED,
      );
    }
  }
}
