const StorageHook = {
  mounted() {
    this.pushEvent("storage:load", this.loadFromStorage());

    this.handleEvent("storage:save", (data) => {
      this.saveToStorage(data);
    });
  },

  loadFromStorage() {
    const stored = localStorage.getItem('content_hub_links');
    return stored ? JSON.parse(stored) : { links: [] };
  },

  saveToStorage(data) {
    localStorage.setItem('content_hub_links', JSON.stringify(data));
  }
};

export default StorageHook;