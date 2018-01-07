import session as sess
import json
import re

def create_cards(deck_key, cards):
    """
    Create cards under a certain deck
    """
    edit_url = "https://ankiuser.net/edit/"
    edit_post_url = "https://ankiuser.net/edit/save"


    with sess.anki_session() as session:
        html = session.get(edit_url).text
        js_params = _get_js_params(html)
        for card in cards:
            card_format = json.dumps([[card['question'], card['answer']], ""])
            submit_info = dict(js_params, **{"data": card_format, "deck": deck_key})

            session.post(edit_post_url, data=submit_info)


def _get_js_params(html):
    csrf_token = re.search("editor.csrf_token2\s=\s\'(\S+)\'", html).group(1)
    mid = re.search("editor.curModelID\s=\s\"(\S+)\"", html).group(1)

    return {"csrf_token": csrf_token, "mid": int(mid)}