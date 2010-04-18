'''
Created on 28 Mar 2010

@author: vampas
'''

import logging
from twisted.web import resource

log = logging.getLogger(__name__)

class Controller(object):

    def get_process_queue(self):
        from baca.application import app
        log.debug("Conversions QUeue QUERIED")
        return app.process_queue

    def get_languages(self, packet, message, locale='en'):
        from baca.application import app
        log.debug("get_locales QUERIED")
        # Get a Connection object from a Flex message.
#        my_flex_message = message.body[0]
#        connection = my_flex_message.connection
#
#        connection.setSessionAttr('new_attr_name', 'value')
#        val = connection.getSessionAttr('new_attr_nam')
        return app.languages

    def get_translations(self, packet, message, locale):
        log.debug("get_translations QUERIED")
        from baca.application import app
        my_flex_message = message.body[0]
        connection = my_flex_message.connection

        connection.setSessionAttr('locale', locale)
#        val = connection.getSessionAttr('new_attr_nam')
        if locale in app.locales:
            return app.locales[locale]
        return app.locales['en']



class UploadResource(resource.Resource):

    def render_POST(self, request):
        from baca.application import app
        app.save_file(request.args['Filename'][0], request.args['Filedata'][0])
        return "OK"

