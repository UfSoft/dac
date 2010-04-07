'''
Created on 28 Mar 2010

@author: vampas
'''

from twisted.web import resource

class Controller(object):
    def echo(self, val):
        return val

    def raiseException(self):
        raise Exception("Example Exception")

    def get_process_queue(self):
        from dac.application import app
        return app.process_queue



class UploadResource(resource.Resource):

    def render_POST(self, request):
        from dac.application import app
        app.save_file(request.args['Filename'][0], request.args['Filedata'][0])
        return "OK"

