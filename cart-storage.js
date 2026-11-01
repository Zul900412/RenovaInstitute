(() => {
    const storageKey = 'renovaInstituteCart';
    const updateEvent = 'renovaInstituteCartUpdated';

    function readCart() {
        const storedCart = localStorage.getItem(storageKey);
        if (!storedCart) return [];

        const cart = JSON.parse(storedCart);
        if (!Array.isArray(cart)) {
            throw new Error('El carrito guardado tiene un formato no válido.');
        }
        return cart;
    }

    function saveCart(cart) {
        if (!Array.isArray(cart)) {
            throw new TypeError('El carrito debe ser una lista de productos.');
        }

        localStorage.setItem(storageKey, JSON.stringify(cart));
        window.dispatchEvent(new CustomEvent(updateEvent, { detail: cart }));
    }

    function subscribe(callback) {
        window.addEventListener(updateEvent, event => callback(event.detail));
        window.addEventListener('storage', event => {
            if (event.key === storageKey) callback(readCart());
        });
    }

    window.RenovaCart = { read: readCart, save: saveCart, subscribe };
})();
