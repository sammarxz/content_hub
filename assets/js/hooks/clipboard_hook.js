const ClipboardHook = {
  mounted() {
    let { to } = this.el.dataset;
    
    this.el.addEventListener("click", (ev) => {
      ev.preventDefault();
      const targetElement = document.querySelector(to);
      
      if (!targetElement || !targetElement.value) {
        this.pushEvent("error", { message: "Não foi possível encontrar o texto para copiar" });
        return;
      }

      this.copyToClipboard(targetElement.value);
    });
  },

  copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text)
        .then(() => this.pushEvent("copied", {}))
        .catch(err => {
          console.error('Erro ao copiar:', err);
          // Tenta o fallback antes de mostrar erro
          this.fallbackCopy(text);
        });
    } else {
      this.fallbackCopy(text);
    }
  },

  fallbackCopy(text) {
    try {
      const tempInput = document.createElement('input');
      tempInput.style.position = 'absolute';
      tempInput.style.left = '-9999px';
      tempInput.value = text;
      document.body.appendChild(tempInput);
      tempInput.select();
      document.execCommand('copy');
      document.body.removeChild(tempInput);
      this.pushEvent("copied", {});
    } catch (err) {
      console.error('Fallback: Erro ao copiar texto', err);
      this.pushEvent("error", { message: "Não foi possível copiar o texto" });
    }
  }
};

export default ClipboardHook;