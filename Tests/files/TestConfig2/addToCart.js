function response(request, cache) {

    // Check the user has logged in.
    if (cache.token == undefined) {
        return Response.unauthorised();
    }

    let payload = request.bodyJSON;
    var cart = cache.cart ?? {};

    console.log("Adding " + payload.id + " to cart");

    var cartItem = cart[payload.id];
    if (cartItem == undefined) {
        console.log("Creating new cart item");
        cartItem = {
            price: payload.price,
            quantity: 0
        }
        console.log("Adding " + cartItem);
        cart[payload.id] = cartItem;
    }

    console.log("Setting quantity in " + cartItem);
    cartItem.quantity = cartItem.quantity + payload.quantity;
    console.log("cart item " + cartItem);
    cart[payload.id] = cartItem;

    cache.cart = cart;
    return Response.ok();
}
