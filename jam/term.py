from sqlalchemy.ext.declarative.api import declarative_base
from sqlalchemy.orm.query import Query
from sqlalchemy.sql.schema import Column, Index
from sqlalchemy.sql.sqltypes import Integer, String, Enum, DateTime, Boolean

SQLAlchemyBase = declarative_base()

"""
Methods:

    Flushed => True
    to_anki()
    to_dict() -> from_dict()
    get_pending() => True
"""

class Term(SQLAlchemyBase):

    __tablename__ = 'terms'

    id = Column(Integer, primary_key=True)

    hirigana = Column(String)
    kanji = Column(String)
    english = Column(String)

    flushed = Column(Boolean)

    @classmethod
    def get_pending(cls):

        return Query(cls).filter(cls.flushed == False)

    @classmethod
    def from_dict(cls, dictionary):

        fields = ['hirigana', 'english', 'kanji']
        s = cls()
        for f in fields:
            setattr(s, f, dictionary[f])
        s.flushed = False
        return s

    def to_dict(self):

        return {'hirigana': self.hirigana, 'english': self.english, 'kanji': self.kanji, 'flushed': self.flushed, 'id': self.id}

    def to_anki(self):

        return [{'question': self.kanji, 'answer': self.hirigana}, {'question': self.kanji, 'answer': self.english}]

