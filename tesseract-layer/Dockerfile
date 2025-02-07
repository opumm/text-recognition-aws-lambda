# Use Amazon Linux 2 base image
FROM amazonlinux:2

# Install necessary tools and dependencies
RUN yum -y update && \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
    epel-release && \
    yum install -y \
    wget \
    gcc \
    cairo-devel \
    pango-devel \
    icu4c-devel \
    leptonica leptonica-devel \
    tesseract

# Create directory for Lambda layer
RUN mkdir -p /opt/bin

# Copy Tesseract and necessary files into the /opt/bin folder for Lambda Layer
RUN cp /usr/bin/tesseract /opt/bin/
RUN cp -r /usr/share/tesseract-ocr /opt/
RUN cp -r /usr/lib64/liblept.* /opt/bin/

# Clean up to reduce image size
RUN yum clean all && rm -rf /var/cache/yum

# Set a default entrypoint (not really needed for the layer, but helpful for debugging)
ENTRYPOINT ["/opt/bin/tesseract"]
