  
console.log("test test test XSS");

let a = document.body.append('h1')
a.style.width = '100%';
a.innerHTML = 'test test XSS';
