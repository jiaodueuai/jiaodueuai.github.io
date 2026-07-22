console.log('JS activado');

const button = document.getElementById("myButton");

function changeText() {
    button.addEventListener("click", function() {
        button.textContent = "Clicked";
    });
}