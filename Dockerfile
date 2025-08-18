# Use multi-stage build with caching optimizations
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04 AS base

# ------------------------------------------------------------
# Consolidated environment variables
# ------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    CMAKE_BUILD_PARALLEL_LEVEL=8

# ------------------------------------------------------------
# System packages + Python 3.12 venv
# ------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
        python3-pip \
        curl wget ffmpeg ninja-build git git-lfs aria2 vim \
        libgl1 libglib2.0-0 build-essential gcc && \
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    python3.12 -m venv /opt/venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/venv/bin:$PATH"


# ------------------------------------------------------------
# PyTorch (CUDA 12.8) & core tooling (no pip cache mounts)
# ------------------------------------------------------------
# 2) Install PyTorch (CUDA 12.8) & freeze torch versions to constraints file
RUN pip install --upgrade pip && \
    pip install --pre torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/nightly/cu128 && \
    # Save exact installed torch versions
    pip freeze | grep -E "^(torch|torchvision|torchaudio)" > /tmp/torch-constraint.txt && \
    # Install core tooling
    pip install packaging setuptools wheel pyyaml gdown triton runpod opencv-python

# 3) Clone ComfyUI
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /ComfyUI

# 4) Install ComfyUI requirements using torch constraint file
RUN cd /ComfyUI && \
    pip install -r requirements.txt --constraint /tmp/torch-constraint.txt

# ------------------------------------------------------------
# Final stage
# ------------------------------------------------------------
# ------------------------------------------------------------
# Final stage
# ------------------------------------------------------------
FROM base AS final
ENV PATH="/opt/venv/bin:$PATH"
ARG CIVITAI_TOKEN
ENV CIVITAI_TOKEN=${CIVITAI_TOKEN}

RUN mkdir -p /models/diffusion_models /models/text_encoders /models/vae /models/clip_vision

# Split diffusion model downloads to avoid 50GB+ layers
#RUN aria2c -x 16 -s 16 -k 1M -d /models/diffusion_models -o wan2.2_t2v_high_noise_14B_fp16.safetensors \
#    https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp16.safetensors
#RUN aria2c -x 16 -s 16 -k 1M -d /models/diffusion_models -o wan2.2_t2v_low_noise_14B_fp16.safetensors \
#    https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors
#RUN aria2c -x 16 -s 16 -k 1M -d /models/diffusion_models -o wan2.2_i2v_high_noise_14B_fp16.safetensors \
#    https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors
#RUN aria2c -x 16 -s 16 -k 1M -d /models/diffusion_models -o wan2.2_i2v_low_noise_14B_fp16.safetensors \
#    https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors
#
## Split text encoders
#RUN aria2c -x 16 -s 16 -k 1M -d /models/text_encoders -o umt5_xxl_fp8_e4m3fn_scaled.safetensors \
#    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors
#
## Split VAE downloads
#RUN aria2c -x 16 -s 16 -k 1M -d /models/vae -o Wan2_1_VAE_bf16.safetensors \
#    https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors
#RUN aria2c -x 16 -s 16 -k 1M -d /models/vae -o wan_2.1_vae.safetensors \
#    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors
#
## Clip vision
#RUN aria2c -x 16 -s 16 -k 1M -d /models/clip_vision -o clip_vision_h.safetensors \
#    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors
#
#
#RUN pip install opencv-python
#
#RUN git clone https://github.com/Hearmeman24/upscalers.git /tmp/upscalers \
#    && cp /tmp/upscalers/4xLSDIR.pth /4xLSDIR.pth \
#    && rm -rf /tmp/upscalers

RUN mkdir -p /models/loras
COPY download_loras.sh /tmp/
COPY model_version_ids.txt /tmp/
RUN chmod +x /tmp/download_loras.sh && /tmp/download_loras.sh -f /tmp/model_version_ids.txt


RUN echo "torch==2.8.0.dev20250511+cu128" > /torch-constraint.txt && \
    echo "torchaudio==2.6.0.dev20250511+cu128" >> /torch-constraint.txt && \
    echo "torchsde==0.2.6" >> /torch-constraint.txt && \
    echo "torchvision==0.22.0.dev20250511+cu128" >> /torch-constraint.txt

# Clone and install all your custom nodes
RUN for repo in \
    https://github.com/kijai/ComfyUI-KJNodes.git \
    https://github.com/Comfy-Org/ComfyUI-Manager.git \
    https://github.com/nonnonstop/comfyui-faster-loading.git \
    https://github.com/rgthree/rgthree-comfy.git \
    https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
    https://github.com/cubiq/ComfyUI_essentials.git \
    https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
    https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git \
    https://github.com/chrisgoringe/cg-use-everywhere.git \
    https://github.com/tsogzark/ComfyUI-load-image-from-url.git; \
  do \
    cd /ComfyUI/custom_nodes; \
    repo_dir=$(basename "$repo" .git); \
    git clone "$repo"; \
    if [ -f "/ComfyUI/custom_nodes/$repo_dir/requirements.txt" ]; then \
      pip install -r "/ComfyUI/custom_nodes/$repo_dir/requirements.txt" --constraint /torch-constraint.txt; \
    fi; \
    if [ -f "/ComfyUI/custom_nodes/$repo_dir/install.py" ]; then \
      python "/ComfyUI/custom_nodes/$repo_dir/install.py"; \
    fi; \
  done


RUN pip install --no-cache-dir \
    https://raw.githubusercontent.com/Hearmeman24/upscalers/master/sageattention-2.1.1-cp312-cp312-linux_x86_64.whl

RUN pip install --no-cache-dir discord.py==2.5.2 \
                              python-dotenv==1.1.0 \
                              Requests==2.32.3 \
                              websocket_client==1.8.0 \
                              "httpx[http2]"

RUN mkdir -p /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/film/

RUN aria2c -x 16 -s 16 -k 1M -d /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/film/ -o film_net_fp32.pt \
    https://d1s3da0dcaf6kx.cloudfront.net/film_net_fp32.pt

# Entrypointtt
COPY src/start_script.sh /start_script.sh
RUN chmod +x /start_script.sh
EXPOSE 8888
CMD ["/start_script.sh"]