# 공통 Python 이미지

Python 3.13–3.15 이미지는 Debian Bookworm과 다음 보안 패치 버전을 사용합니다.

- `python_docker:3.13` → `python:3.13.17-bookworm`
- `python_docker:3.14` → `python:3.14.9-bookworm`
- `python_docker:3.15` → `python:3.15.1-bookworm`

세 버전 모두 수정된 pip 26.2.2와 certifi 2026.10.19를 번들합니다.
Dockerfile의 기본값은 3.13.17이며, `PYTHON_VARIANT`로 배포판을 지정할 수 있습니다.
보안 검증 대상 배포판은 Bookworm입니다.
3.11·3.12는 빌드 대상에서 제외했습니다. 기존 GHCR 태그는 갱신하지 않으며,
사용처의 Python 버전 전환은 각 프로젝트에서 진행합니다.

## Bullseye에서 Bookworm으로 변경한 이유

- **빌드 복구:** 2026-10-23 검증에서 Bullseye의 `apt-get update` 후에도
  `jq`, `unzip`, `libglib2.0-0` 등 보안 패키지 다운로드가 `404 Not Found`로
  실패했습니다. HTTPS와 다른 Debian 미러에서도 재현됐으며, Bookworm 시험
  빌드는 해당 패키지와 Docker 설치까지 완료됐습니다.
- **보안 유지보수:** [Bullseye의 공개 LTS 지원](https://www.debian.org/releases/bullseye/)은
  2026-08-31에 종료됐습니다. 공통 이미지의 OS 보안 업데이트를 계속 받기 위해
  [2028-06-30까지 LTS 지원되는 Bookworm](https://www.debian.org/releases/bookworm/)을
  기본값으로 선택했습니다.
- **기본 배포판 통일:** 지원하는 Python 버전에 Bookworm을 적용해 OS 패키지와
  인증서 관리 차이를 줄였습니다.

## 로컬 빌드와 검증

`CR_USER`, `CR_PAT`가 모두 설정되면 `build.sh`가 이미지를 GHCR에 푸시합니다.
로컬 검증 시에는 아래처럼 두 변수를 제거합니다.

```bash
env -u CR_USER -u CR_PAT PLATFORM=linux/amd64 bash python_docker/build.sh 3.13
docker run --rm --network=none --platform=linux/amd64 \
  -v "$PWD/python_docker/test_security.py:/tests/test_security.py:ro" \
  atflow-corp/python_docker:3.13 python /tests/test_security.py
```

버전 인수는 `3.13`, `3.14`, `3.15`를 받으며, 생략하면 세 버전을 모두 빌드합니다.
기본 플랫폼은 모두 `linux/amd64,linux/arm64`입니다. 로컬 arm64 이미지에는
`-linux-arm64` 태그 접미사가 붙습니다. 빌드는 항상 `--pull --no-cache`로
베이스 이미지와 OS 패키지를 새로 조회합니다. 기존 컨테이너에는 자동 반영되지 않습니다.

Bookworm 전환으로 glibc는 2.36 계열, Debian의 `awscli` 패키지는 v2가 됩니다.
사용처의 네이티브 의존성과 배포 명령은 새 이미지에서 검증하고, Bullseye에서
만든 venv 캐시는 재사용하지 않습니다.

## eMudhra 인증서 대응

- 수정된 pip를 번들한 Python 보안 릴리스를 베이스로 사용합니다. 전역 pip와
  새 venv가 같은 수정본을 사용하며, 별도 pip 설치나 CPython 내부 수정은 필요하지 않습니다.
- OS `ca-certificates`는 Debian 보안 업데이트로 갱신합니다. Bookworm의
  수정 버전은 `20250419~deb12u2`이며, 두 문제 루트 인증서를 제거하므로 수동 차단은 필요하지 않습니다.
- Debian AWS CLI의 botocore 인증서 번들도 OS 저장소에 연결합니다. 별도 번들에
  남아 있는 `AAA Certificate Services`를 통한 우회 신뢰를 차단합니다.
- `test_security.py`는 OS 번들·인증서 디렉터리·pip·Debian Python 패키지 번들에서
  문제의 루트 인증서가 없는지와 전역·번들 pip 버전을 오프라인으로 확인합니다.

이 이미지는 uv나 애플리케이션용 certifi를 설치하지 않습니다. 사용처에서
`uv>=0.13.4`, `certifi>=2026.10.19`를 적용하고, 이전 venv를 복원하는 캐시도
갱신해야 합니다. 기존 venv의 pip는 각 사용처 프로젝트에서 별도로 업데이트하거나
새 이미지의 Python으로 venv를 다시 생성해야 합니다.

근거: [Python 보안 릴리스](https://blog.python.org/2026/10/python-3151-3149-31317/),
[Python 보안팀 공지](https://discuss.python.org/t/information-for-python-users-regarding-emudhra-emsign-ca-certificate-security-incident/109576),
[Debian Bookworm 보안 업데이트](https://security-tracker.debian.org/tracker/DLA-4845-1),
[인증서 사고 대응 안내](https://emudhra.we-have-a-problem.com/),
[Debian Bullseye 지원 기간](https://www.debian.org/releases/bullseye/).
