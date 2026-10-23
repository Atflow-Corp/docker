# 공통 Python 이미지

Python 3.11–3.14 이미지는 기본적으로 Debian Bookworm을 사용합니다.
`PYTHON_VARIANT`로 배포판을 지정할 수 있습니다.

## Bullseye에서 Bookworm으로 변경한 이유

- **빌드 복구:** 2026-10-23 검증에서 Bullseye의 `apt-get update` 후에도
  `jq`, `unzip`, `libglib2.0-0` 등 보안 패키지 다운로드가 `404 Not Found`로
  실패했습니다. HTTPS와 다른 Debian 미러에서도 재현됐으며, Bookworm 시험
  빌드는 해당 패키지와 Docker 설치까지 완료됐습니다.
- **보안 유지보수:** [Bullseye의 공개 LTS 지원](https://www.debian.org/releases/bullseye/)은
  2026-08-31에 종료됐습니다. 공통 이미지의 OS 보안 업데이트를 계속 받기 위해
  [2028-06-30까지 LTS 지원되는 Bookworm](https://www.debian.org/releases/bookworm/)을
  기본값으로 선택했습니다.
- **기본 배포판 통일:** 기존 Python 3.14 빌드에서 사용하던 Bookworm을
  3.11–3.13에도 적용해 Python 버전별 OS 패키지와 인증서 관리 차이를 줄였습니다.

## 로컬 빌드와 검증

`CR_USER`, `CR_PAT`가 모두 설정되면 `build.sh`가 이미지를 GHCR에 푸시합니다.
로컬 검증 시에는 아래처럼 두 변수를 제거합니다.

```bash
env -u CR_USER -u CR_PAT PLATFORM=linux/amd64 bash python_docker/build.sh 3.11
docker run --rm --network=none --platform=linux/amd64 \
  -v "$PWD/python_docker/test_security.py:/tests/test_security.py:ro" \
  atflow-corp/python_docker:3.11 python /tests/test_security.py
```

버전을 생략하면 3.11–3.14를 빌드합니다. 3.11의 기본 플랫폼은 `linux/amd64`,
3.12–3.14는 `linux/amd64,linux/arm64`입니다. 빌드 시 최신 베이스 이미지를
조회하며, 로컬 arm64 이미지에는 `-linux-arm64` 태그 접미사가 붙습니다.
기존 이미지의 패키지 레이어까지 다시 만들려면 `docker buildx build`에
`--pull --no-cache`를 지정합니다. 기존 컨테이너에는 자동 반영되지 않습니다.

Bookworm 전환으로 glibc는 2.36 계열, Debian의 `awscli` 패키지는 v2가 됩니다.
사용처의 네이티브 의존성과 배포 명령은 새 이미지에서 검증하고, Bullseye에서
만든 venv 캐시는 재사용하지 않습니다.

## eMudhra 인증서 대응

- pip 26.2.2 wheel을 SHA-256으로 검증한 뒤 전역 pip와 `ensurepip` 번들에
  동일하게 사용합니다. 새 `python -m venv`도 네트워크 없이 수정된 pip를 설치합니다.
  CPython의 `ensurepip` 내부 버전 상수를 수정하므로, 번들 구조가 바뀌면 빌드를
  실패시키고 확인하도록 했습니다.
- OS `ca-certificates`를 갱신하고 `emSign ECC Root CA - G3`와
  `AAA Certificate Services`를 비활성화합니다. pip는 자체 certifi 외에 OS
  인증서도 신뢰하므로 두 저장소를 함께 처리해야 합니다.
- Debian AWS CLI의 botocore 인증서 번들도 OS 저장소에 연결합니다. 별도 번들에
  남아 있는 `AAA Certificate Services`를 통한 우회 신뢰를 차단합니다.
- `test_security.py`는 OS 번들·인증서 디렉터리·pip·Debian Python 패키지 번들에서
  문제의 루트 인증서가 없는지와 전역 pip·새 venv의 pip 버전을 오프라인으로 확인합니다.

이 이미지는 uv나 애플리케이션용 certifi를 설치하지 않습니다. 사용처에서
`uv>=0.13.4`, `certifi>=2026.10.19`를 적용하고, 이전 venv를 복원하는 캐시도
갱신해야 합니다. 이미 존재하는 venv의 pip는 별도로 업데이트해야 합니다.

근거: [Python 보안팀 공지](https://discuss.python.org/t/information-for-python-users-regarding-emudhra-emsign-ca-certificate-security-incident/109576),
[인증서 사고 대응 안내](https://emudhra.we-have-a-problem.com/),
[Debian Bullseye 지원 기간](https://www.debian.org/releases/bullseye/).
