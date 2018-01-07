from contextlib import contextmanager

import bs4
import re
import term

from sqlalchemy.engine import create_engine
from sqlalchemy.orm.session import sessionmaker

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

def _fmt_suiren_english(text):

    words = re.findall('[A-Z][^A-Z]*', text)
    words = "; ".join(words)
    return words

def _complete_term(ter):

    with session_context() as session:

        q = session.query(term.Term).filter(term.Term.kanji == ter)
        if q.count() != 0:
            return q.first().to_dict()
        q = session.query(term.Term).filter(term.Term.hirigana == ter)
        if q.count() != 0:
            return q.first().to_dict()
        else:
            return session.query(term.Term).filter(term.Term.english == ter).first().to_dict()

def get_selected_word_from_suiren(html):

    soup = bs4.BeautifulSoup(html)
    legend = soup.find('div', {'id': 'legend'})
    return {'kanji': legend.find('h1').get_text(), 'hirigana': legend.find('p').get_text(),  'english': _fmt_suiren_english(legend.find('div', {'class': 'english'}).get_text())}

def get_selected_word_from_anki(html):

    soup = bs4.BeautifulSoup(html)
    qz = soup.find('div', {'id': 'qa'})
    return _complete_term(qz.get_text().split('\n')[-1])