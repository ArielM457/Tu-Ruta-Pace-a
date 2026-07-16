import { HttpStatus } from '@nestjs/common';
import { DomainException } from '../../common/exceptions/domain.exception';

interface PostgrestErrorLike {
  message: string;
  code?: string;
}

export const UNIQUE_VIOLATION_CODE = '23505';

export function assertNoDatabaseError(error: PostgrestErrorLike | null): void {
  if (!error) {
    return;
  }
  throw new DomainException(
    'DATABASE_ERROR',
    `Error de base de datos: ${error.message}`,
    HttpStatus.INTERNAL_SERVER_ERROR,
  );
}

export function isUniqueViolation(error: PostgrestErrorLike | null): boolean {
  return error?.code === UNIQUE_VIOLATION_CODE;
}
