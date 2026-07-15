프로젝트 실행
1. .env 파일 생성: cp .env.example .env (VITE_OPENAI_API_KEY 포함)
2. 설치: npm install
3. 개발: npm run dev
4. 빌드: npm run build
5. Netlify: Git 리포지토리 연결 후 배포(환경변수 VITE_OPENAI_API_KEY 설정 권장)

주의: Vite의 VITE_ 접두사 환경변수는 클라이언트 번들에 포함되어 노출됩니다. 데모/테스트용으로만 사용하세요.
