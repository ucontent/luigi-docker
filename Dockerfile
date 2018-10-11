ARG BASE=dellelce/py-base
FROM $BASE as build

LABEL maintainer="Antonio Dell'Elce"


# temp install line before switching to use multi-stage install
RUN apk add --no-cache gcc binutils gfortran make libc-dev linux-headers \
                       libxslt-dev

# commands are intended for busybox: if BASE is changed to non-BusyBox these may fail!
ARG GID=2001
ARG UID=2000
ARG GROUP=luigi
ARG USERNAME=luigi
ARG BASEDATA=/app/data
ARG DATA=${BASEDATA}/${USERNAME}
ARG LUIGIPORT=8000
ARG LUIGIHOME=/home/${USERNAME}
ARG LUIGIENV=/home/${USERNAME}/air-env

ENV ENV   $LUIGIHOME/.profile

RUN mkdir -p ${BASEDATA} && chmod 777 ${BASEDATA} \
    && addgroup -g "${GID}" "${GROUP}" && adduser -D -s /bin/sh \
       -g "luigi user" \
       -G "${GROUP}" -u "${UID}" \
       "${USERNAME}"

USER ${USERNAME}

RUN    mkdir -p "${LUIGIENV}" && chown "${USERNAME}":"${GROUP}" "${LUIGIENV}" \
    && chown -R "${USERNAME}:${GROUP}" "${LUIGIHOME}" \
    && mkdir -p "${DATA}" && chown "${USERNAME}":"${GROUP}" "${DATA}" \
    && cd "${LUIGIENV}" && "${INSTALLDIR}/bin/python3" -m venv . \
    && echo '. '${LUIGIENV}'/bin/activate'           >> ${LUIGIHOME}/.profile

WORKDIR $LUIGIENV
COPY requirements.txt  /tmp/requirements.txt

# install luigi and requirements
RUN    . ${LUIGIENV}/bin/activate \
    && pip install -U pip setuptools \
    && SLUGIFY_USES_TEXT_UNIDECODE=yes pip install -r /tmp/requirements.txt

VOLUME ${DATA}
ENV LUIGIDATA  ${DATA}

EXPOSE ${LUIGIPORT}:${LUIGIPORT}

