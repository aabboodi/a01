@echo off
echo [1/3] Starting Database Containers...
cd backend
:: تشغيل قاعدة البيانات وانتظارها قليلاً
docker-compose up -d

echo [2/3] Checking configuration...
:: لا نقوم بنسخ الملف لكي لا نخرب الإعدادات الحالية
if not exist .env copy .env.example .env

echo [3/3] Starting Backend Server...
:: تثبيت المكتبات فقط إذا تغيرت (لتسريع العمل)
call npm install
npm run start:dev