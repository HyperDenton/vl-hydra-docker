FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu16.04

# install anaconda 5.2.0
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN sed -i "s/archive.ubuntu./mirrors.aliyun./g" /etc/apt/sources.list
RUN sed -i "s/deb.debian.org/mirrors.aliyun.com/g" /etc/apt/sources.list
RUN sed -i "s/security.debian.org/mirrors.aliyun.com\/debian-security/g" /etc/apt/sources.list

RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion

RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-5.2.0-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]

# install pytorch 1.5 and cudatoolkit
RUN conda clean -i
RUN conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
RUN conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch
RUN conda config --set show_channel_urls yes

RUN wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/linux-64/cudatoolkit-10.2.89-hfd86e86_1.tar.bz2 -o /tmp/cudatoolkit-10.2.89-hfd86e86_1.tar.bz2
RUN conda install /tmp/cudatoolkit-10.2.89-hfd86e86_1.tar.bz2
RUN rm /tmp/cudatoolkit-10.2.89-hfd86e86_1.tar.bz2

RUN wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/linux-64/pytorch-1.5.1-py3.6_cuda10.2.89_cudnn7.6.5_0.tar.bz2 -o /tmp/pytorch-1.5.1-py3.6_cuda10.2.89_cudnn7.6.5_0.tar.bz2 && \
    conda install ./pytorch-1.5.1-py3.6_cuda10.2.89_cudnn7.6.5_0.tar.bz2 && \
    rm ./pytorch-1.5.1-py3.6_cuda10.2.89_cudnn7.6.5_0.tar.bz2

RUN wget --quiet https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/linux-64/python-3.6.10-h7579374_2.tar.bz2 && \
    conda install ./python-3.6.10-h7579374_2.tar.bz2 && \
    rm ./python-3.6.10-h7579374_2.tar.bz2

RUN conda install pytorch=1.5 torchvision cudatoolkit=10.2

# install fvcore, see https://github.com/facebookresearch/detectron2/issues/458
RUN pip install opencv-python -i https://pypi.tuna.tsinghua.edu.cn/simple
RUN pip install "git+https://github.com/philferriere/cocoapi.git#egg=pycocotools&subdirectory=PythonAPI"
RUN pip install 'git+https://github.com/facebookresearch/detectron2.git@5e2a6f62ef752c8b8c700d2e58405e4bede3ddbe'

# clone and install, see https://github.com/MILVLG/bottom-up-attention.pytorch
RUN mkdir /workspace

RUN cd /workspace && \
    git clone https://github.com/NVIDIA/apex.git && \
    cd apex && \
    python setup.py install

RUN cd /workspace && \
    git clone https://github.com/MILVLG/bottom-up-attention.pytorch && \
    cd bottom-up-attention.pytorch && \
    python setup.py build develop

WORKDIR /workspace/bottom-up-attention.pytorch
