import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';
import { AppConfigService } from '../../config/app-config.service';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { DomainException } from '../exceptions/domain.exception';
import { AuthenticatedUser, UserRole } from '../types/domain';

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  private readonly jwks: ReturnType<typeof createRemoteJWKSet>;
  private readonly issuer: string;

  constructor(
    private readonly reflector: Reflector,
    private readonly appConfig: AppConfigService,
  ) {
    this.issuer = `${this.appConfig.supabaseUrl}/auth/v1`;
    this.jwks = createRemoteJWKSet(
      new URL(`${this.issuer}/.well-known/jwks.json`),
    );
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
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
    request.user = await this.verifyToken(token);
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

  private async verifyToken(token: string): Promise<AuthenticatedUser> {
    try {
      const { payload } = await jwtVerify(token, this.jwks, {
        issuer: this.issuer,
      });
      const subject = (payload as JWTPayload).sub;
      if (!subject) {
        throw new Error('missing subject');
      }
      return { userId: subject, role: UserRole.Citizen };
    } catch {
      throw new DomainException(
        'INVALID_TOKEN',
        'El token de autenticación no es válido o expiró',
        HttpStatus.UNAUTHORIZED,
      );
    }
  }
}
