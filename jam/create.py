from sqlalchemy.engine import create_engine

import term

connection_string = 'sqlite:///storage.db'
engine = create_engine(connection_string)


if __name__ == '__main__':

    term.SQLAlchemyBase.metadata.create_all(engine)