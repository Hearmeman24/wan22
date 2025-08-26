#!/bin/bash
cd /models/loras || exit 1

# Function to download a file with proper URL encoding
download_file() {
  filename="$1"
  # URL encode the filename for the URL
  encoded_url=$(echo "$filename" | sed -e "s/ /%20/g")
  echo "Downloading $filename..."
  wget -q -O "$filename" "https://d1s3da0dcaf6kx.cloudfront.net/wan22/$encoded_url" || {
    echo "Failed to download $filename"
    return 1
  }
  echo "Successfully downloaded $filename"
  return 0
}

# Download all LoRA files
download_file "SaggyTits_wan22_e20_high.safetensors"
download_file "SaggyTits_wan22_e25_low.safetensors"
download_file "Wan2.2 - T2V - Dildo Ride - HIGH 14B.safetensors"
download_file "Wan2.2 - T2V - Dildo Ride - LOW 14B.safetensors"
download_file "Wan2.2 - T2V - Doggy Style  - HIGH 14B.safetensors"
download_file "Wan2.2 - T2V - Doggy Style - LOW 14B.safetensors"
download_file "Wan2.2 - T2V - Hand in Panties - HIGH 14B.safetensors"
download_file "Wan2.2 - T2V - Hand in Panties - LOW 14B.safetensors"
download_file "Wan2.2 - T2V - Orgasm - HIGH 14B.safetensors"
download_file "Wan2.2 - T2V - Orgasm - LOW 14B.safetensors"
download_file "Wan2.2 - T2V - POV Hand Job - HIGH 14B.safetensors"
download_file "Wan2.2 - T2V - POV Hand Job - LOW 14B.safetensors"
download_file "Wan2.2 - T2V - Pillow Humping - HIGH 14B.safetensors"
download_file "Wan2.2 - T2V - Pillow Humping - LOW 14B.safetensors"
download_file "Wan2.2 - T2V - Stroking It - HIGH 14B.safetensors"
download_file "Wan2.2 - T2V - Stroking It - LOW 14B.safetensors"
download_file "Wan2.2 - T2V - The Ratio - HIGH 14B.safetensors"
download_file "Wan2.2 - T2V - The Ratio - LOW 14B.safetensors"
download_file "Wan2.2 - T2V - Tiny Panties - HIGH 14B.safetensors"
download_file "Wan2.2 - T2V - Tiny Panties - LOW 14B.safetensors"
download_file "Wan2.2 - v2 - Insta Girls - HIGH 14b.safetensors"
download_file "Wan2.2 - v2 - Insta Girls - LOW 14B.safetensors"
download_file "Wan2.2 v2 - T2V - Cowgirl - HIGH 14B.safetensors"
download_file "Wan2.2 v2 - T2V - Cowgirl - LOW 14B.safetensors"
download_file "huge-titfuck-high.safetensors"
download_file "huge-titfuck-low.safetensors"
download_file "pworship_high_noise.safetensors"
download_file "pworship_low_noise.safetensors"
download_file "wan2.2-i2v-high-oral-insertion-v1.0.safetensors"
download_file "wan2.2-i2v-low-oral-insertion-v1.0.safetensors"
download_file "wan2.2_highnoise_cumshot_v.1.0.safetensors"
download_file "wan2.2_lownoise_cumshot_v1.0.safetensors"
download_file "wan2.2_t2v_highnoise_pov_missionary_v1.0.safetensors"
download_file "wan2.2_t2v_lownoise_pov_missionary_v1.0.safetensors"
download_file "wan22-side-deepthroat-12epoc-low-k3nk.safetensors"
download_file "wan22-side-deepthroat-54epoc-high-k3nk.safetensors"
echo "All LoRA files downloaded successfully"