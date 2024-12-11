const DownloadHook = {
  mounted() {
    this.handleEvent("file:download", ({ data, filename, mime_type }) => {
      const blob = new Blob([data], { type: mime_type });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      a.click();
      window.URL.revokeObjectURL(url);
    });
  }
};

export default DownloadHook;