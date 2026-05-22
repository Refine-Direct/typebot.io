@ECHO OFF

REM Stop services
call pm2 stop all
REM Install dependencies
call bun install
REM Database migration
bunx nx db:migrate prisma
REM Build builder and viewer
bunx nx run-many -t build -p builder,viewer
REM Restart services
call pm2 start all
exit 0


call bun install
call bunx turbo build --filter=builder... --filter=viewer...
call pm2 reload all
exit 0

call pm2 stop all
call bun install
rem call bunx turbo db:migrate
call bunx turbo build --filter=builder... --filter=viewer...
call pm2 start all