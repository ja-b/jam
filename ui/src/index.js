import './main.css';
import { Main } from './Main.elm';

var app = Main.embed(document.getElementById('root'), window.location.origin);

app.ports.requestForSuirenHTML.subscribe(function (arg) {
    var html = document.getElementById("suiren").contentWindow.document.body.innerHTML;
    app.ports.ackForSuirenHTML.send(html);
});

app.ports.requestForAnkiHTML.subscribe(function (arg) {
    var html = document.getElementById("anki").contentWindow.document.body.innerHTML;
    app.ports.ackForAnkiHTML.send(html);
});
