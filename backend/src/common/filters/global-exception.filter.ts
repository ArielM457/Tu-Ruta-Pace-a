import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';

interface ErrorDescription {
  status: number;
  code: string;
  message: string;
}

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    const description = this.describe(exception);
    if (description.status >= 500) {
      this.logger.error(description.message, (exception as Error)?.stack);
    }
    response.status(description.status).json({
      data: null,
      error: { code: description.code, message: description.message },
    });
  }

  private describe(exception: unknown): ErrorDescription {
    if (exception instanceof HttpException) {
      return this.describeHttpException(exception);
    }
    return {
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      code: 'INTERNAL_ERROR',
      message: 'Ocurrió un error inesperado',
    };
  }

  private describeHttpException(exception: HttpException): ErrorDescription {
    const status = exception.getStatus();
    const body = exception.getResponse();
    if (typeof body === 'string') {
      return { status, code: this.codeFromStatus(status), message: body };
    }
    const record = body as Record<string, unknown>;
    const code =
      typeof record.code === 'string'
        ? record.code
        : this.codeFromStatus(status);
    const message = this.extractMessage(record, exception.message);
    return { status, code, message };
  }

  private extractMessage(
    record: Record<string, unknown>,
    fallback: string,
  ): string {
    const rawMessage = record.message;
    if (Array.isArray(rawMessage)) {
      return rawMessage.join('; ');
    }
    if (typeof rawMessage === 'string') {
      return rawMessage;
    }
    return fallback;
  }

  private codeFromStatus(status: number): string {
    return HttpStatus[status] ?? 'ERROR';
  }
}
