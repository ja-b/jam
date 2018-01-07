import requests
from contextlib import contextmanager
import bs4

@contextmanager
def anki_session():
    login_url = 'https://ankiweb.net/account/login'
    logout_url = 'https://ankiweb.net/account/logout'

    #Heres my password guys -- have fun!!
    user_info = {'username': 'jacob.bennett29@gmail.com', 'password': 'ankiwebMNB'}

    with requests.Session() as session:
        html = session.get(login_url).text
        token = _get_csrf_token(html)
        login_info = user_info
        login_info['submitted'] = 1
        login_info['csrf_token'] = token
        session.post(login_url, data=login_info)
        try:
            yield session
        except Exception as err:
            session.get(logout_url)
            raise err
        session.get(logout_url)

def _get_csrf_token(html):

    soup = bs4.BeautifulSoup(html)
    elem = soup.find("input", {"name": 'csrf_token'})
    return elem['value']