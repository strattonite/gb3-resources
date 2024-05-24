FROM ghcr.io/f-of-e/gb3-tools:latest

RUN apt-get update
RUN apt-get install -y qtcreator
RUN apt-get install -y qtbase5-dev
RUN apt-get install -y qt5-qmake

RUN rm -rf /f-of-e-tools/
RUN git clone --recursive https://github.com/f-of-e/f-of-e-tools.git
RUN rm -rf /f-of-e-tools/.git

RUN cd /f-of-e-tools/tools/nextpnr && cmake -DARCH=ice40 -DBUILD_GUI=ON -DBUILD_PYTHON=ON -DBUILD_HEAP=OFF .
RUN cd /f-of-e-tools/tools/nextpnr && make
RUN cd /f-of-e-tools/tools/nextpnr && make install

RUN rm -rf /f-of-e-tools/tools/nextpnr
RUN rm -rf /f-of-e-tools/tools/icestorm
RUN rm -rf /f-of-e-tools/tools/arachnepnr
RUN rm -rf /f-of-e-tools/tools/srec2hex
RUN rm -rf /f-of-e-tools/tools/yosys