'''
Created on 28 Mar 2010

@author: vampas
'''

import logging
from twisted.web import resource

log = logging.getLogger(__name__)

class Controller(object):
    def echo(self, val):
        return val

    def raiseException(self):
        raise Exception("Example Exception")

    def get_process_queue(self):
        from baca.application import app
        log.debug("Conversions QUeue QUERIED")
        return app.process_queue



class UploadResource(resource.Resource):

    def render_POST(self, request):
        from baca.application import app
        app.save_file(request.args['Filename'][0], request.args['Filedata'][0])
        return "OK"

