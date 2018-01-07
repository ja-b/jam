import traceback
from contextlib import contextmanager

import flask
import flask_socketio
from flask.globals import request
from flask.helpers import send_from_directory
from sqlalchemy.engine import create_engine
from sqlalchemy.orm.session import sessionmaker
from flask import jsonify
import bs4

from flask_cors import CORS, cross_origin

import term
import anki
import scrape

connection_string = 'sqlite:///storage.db'
engine = create_engine(connection_string)
Session = sessionmaker(bind=engine)

@contextmanager
def session_context():

    s = Session()
    try:
        yield s
    except Exception as exc:
        s.close()
        raise exc
    s.close()

app = flask.Flask(__name__, static_url_path='', static_folder='../ui/build')

@app.route('/terms', methods=['GET'])
def get_terms():

    with session_context() as session:

        terms = term.Term.get_pending().with_session(session).all()
        return jsonify([t.to_dict() for t in terms])

@app.route('/get_opp/{ter:string}')
def get_opposite(ter):

    with session_context() as session:

        q = session.query(term.Term).filter(term.Term.kanji == ter)
        if q.exists:
            return q.first().kanji
        q = session.query(term.Term).filter(term.Term.hirigana == ter)
        if q.exists:
            return q.first().hirigana
        else:
            return session.query(term.Term).filter(term.Term.english == ter).first().english

@app.route('/terms', methods=['POST'])
def create_terms():

    with session_context() as session:

        terms = request.get_json()
        for t in terms:
            tm = term.Term.from_dict(t)
            session.add(tm)
        session.commit()
    return jsonify(True)

@app.route('/terms/flush', methods=['POST'])
def flush_terms():

    with session_context() as session:

        terms = term.Term.get_pending().with_session(session).all()
        fmt_terms = []
        for tm in terms:
            fmt_terms.extend(tm.to_anki())
        anki.create_cards('Japanese1', fmt_terms)
        for tm in terms:
            tm.flushed = True
        session.commit()
    return jsonify(True)

@app.route('/process_anki', methods=['POST'])
def process_ankiweb_html():

    html = request.get_json()['html']
    return jsonify(scrape.get_selected_word_from_anki(html))

@app.route('/process_kanjidamage', methods=['POST'])
def process_kanjidamage():

    pass

@app.route('/process_suiren', methods=['POST'])
def process_suiren():

    html = request.get_json()['html']
    return jsonify(scrape.get_selected_word_from_suiren(html))

@app.route('/')
def get_ui():

    return app.send_static_file('index.html')

CORS(app)
#socketio = flask_socketio.SocketIO(app)

if __name__ == '__main__':

    app.run(host='0.0.0.0', port=3001, debug=True)

