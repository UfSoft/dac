# -*- coding: utf-8 -*-
# vim: sw=4 ts=4 fenc=utf-8 et
"""
    dac.application
    ~~~~~~~~~~~~~~~

    This module is responsible for the whole application.

    :copyright: © 2010 UfSoft.org - Pedro Algarvio <ufs@ufsoft.org>
    :license: BSD, see LICENSE for more details.
"""
import gst
import shutil
import amfast
import logging
from ConfigParser import SafeConfigParser
from os.path import abspath, basename, dirname, expanduser, isdir, join
from types import ModuleType
from os import makedirs, listdir, remove
from os.path import basename, dirname, join, splitext

from twisted.web import static, server, resource, vhost
from twisted.internet import reactor
from twisted.internet.threads import deferToThread
from twisted.internet.task import LoopingCall
from amfast.remoting import Service, CallableTarget
from amfast.remoting.twisted_channel import TwistedChannelSet, TwistedChannel, StreamingTwistedChannel

from dac import controllers

usefull_path = lambda path: abspath(expanduser(path))

log = None


class Conversion(object):
    def __init__(self, filename):
        self.id = id(self)
        self.filename = filename
        self.out_filename = "%s.mp2" % splitext(filename)[0]
        self.progress = 0
        self.processing = False
        self.converted = False
        self.in_filepath = join(app.config.uploads_dir, filename)
        self.out_filepath = join(app.config.downloads_dir, "%s.mp2" % filename)
        self.url = '/downloads/%s' % basename(self.out_filepath)

    def process(self):
        log.debug("Started processing %s", self)
#        pipeline_str = (
#            "filesrc location=\"%s\" ! decodebin2 ! audioconvert ! "
#            "audio/x-raw-int,channels=2 ! audioresample ! "
#            "progressreport update-freq=1 silent=TRUE ! ffenc_mp2 ! "
#            "ffmux_mp2 ! filesink location=\"%s\"" % (self.in_filepath,
#                                                      self.out_filepath)
#        )
        pipeline_str = (
            "filesrc location=\"%s\" ! decodebin2 ! queue ! audioconvert ! audioresample ! "
            "progressreport update-freq=1 silent=TRUE ! "
            "audio/x-raw-int,channels=2, depth=(int)16, rate=(int)48000, signed=(boolean)true ! "
            "twolame bitrate=256 mode=0 energy-level-extension=true error-protection=true ! "
            "queue ! filesink location=\"%s\"" % (self.in_filepath,
                                                                      self.out_filepath)
        )
#        pipeline_str = (
#            "filesrc location=\"%s\" ! decodebin2 ! queue ! audioconvert ! audioresample ! "
#            "audio/x-raw-int,channels=2, depth=(int)16, rate=(int)48000, signed=(boolean)true ! "
#            "progressreport update-freq=1 silent=TRUE ! faac bitrate=256000 ! audio/mpeg, mpegversion=(int)2, channels=(int)2 rate=(int)48000 ! "
#            "queue ! ffmux_mp4 ! filesink location=\"%s\"" % (self.in_filepath,
#                                                      self.out_filepath)
#        )

        self.pipeline = gst.parse_launch(pipeline_str)
        log.debug("Launch Pipeline: '%s'", pipeline_str)
        bus = self.pipeline.get_bus()
        bus.add_signal_watch()
        bus.connect("message", self.on_message)
        bus.connect("message::eos", self.on_eos_message)
        self.processing = True
        ret, state, pending = self.pipeline.get_state(0)
        if state is not gst.STATE_PLAYING:
            self.pipeline.set_state(gst.STATE_PLAYING)

    def stop(self):
        log.debug("Stopping process of %s at %d%%", self, self.progress)
        ret, state, pending = self.pipeline.get_state(0)
        if state is not gst.STATE_NULL:
            self.pipeline.set_state(gst.STATE_NULL)
        self.processing = False
        log.debug("Removing uploaded file: %s", self.filename)
        remove(self.in_filepath)

    def on_message(self, bus, message):
        if message.structure and message.structure.get_name() == 'progress':
            progress = message.structure['percent-double']
            #log.debug("converted %d%% of %s", progress, self)
            self.set_progress(progress)

    def on_eos_message(self, bus, message):
        self.set_progress(100.0)
        self.converted = True
        app.emit_flex_object(body=self, topic="conversions", sub_topic='complete')
        app.emit_flex_object(body=self, topic="conversions", sub_topic=str(self.id))
        self.stop()

    def set_progress(self, value):
        self.progress = value
        app.emit_flex_object(body=self, topic="conversions", sub_topic='update')
        app.emit_flex_object(body=self, topic="conversions", sub_topic=str(self.id))

    def __repr__(self):
        return "<%s %s>" % (self.__class__.__name__, self.filename)

class Application(object):
    def __init__(self):
        self.config = ModuleType('afm.config')
        self.config.file = 'dac.ini'
        self.config.parser = SafeConfigParser()
        self.processing = False
        self.process_queue = []
        self.process_queue_listener_task = LoopingCall(self.check_process_queue)
        self.process_queue_listener_task.start(5, False)

    def config_initial_populate(self):
        parser = self.config.parser
        parser.add_section('main')
        parser.set("main", "uploads_dir", '%(here)s/uploads')
        parser.set("main", "downloads_dir", '%(here)s/downloads')
        parser.set("main", "logging_config_file", '%(here)s/logging.ini')

    def config_load(self, config_dir=None):
        config_dir = config_dir or self.config.dir
        parser = self.config.parser
        parser.read([join(config_dir, self.config.file)])
        self.config.parser.set('DEFAULT', 'here', config_dir)
        self.config.uploads_dir = usefull_path(parser.get(
                                                    'main', 'uploads_dir'))
        self.config.downloads_dir = usefull_path(parser.get(
                                                    'main', 'downloads_dir'))
        if not isdir(self.config.uploads_dir):
            makedirs(self.config.uploads_dir)
        if not isdir(self.config.downloads_dir):
            makedirs(self.config.downloads_dir)
        self.config.logging_config_file = usefull_path(parser.get(
                                                'main', 'logging_config_file'))


        for idx, filename in enumerate(listdir(self.config.uploads_dir)):
            reactor.callLater(5*idx, self.add_conversion, filename)

    def config_save(self, config_dir=None):
        config_dir = config_dir or self.config.dir
        self.config.parser.remove_option('DEFAULT', 'here')
        self.config.parser.remove_section('DEFAULT')
        self.config.parser.write(open(join(config_dir, self.config.file), 'w'))

    def build_root(self):
        from amfast.encoder import Encoder
        from amfast.decoder import Decoder
        from amfast.class_def.code_generator import CodeGenerator
        from amfast.class_def import ClassDefMapper, DynamicClassDef

        # If the code is completely asynchronous,
        # you can use the dummy_threading module
        # to avoid RLock overhead.
#        import dummy_threading
#        amfast.mutex_cls = dummy_threading.RLock

        share_path = join(dirname(__file__), 'shared')
        root = vhost.NameVirtualHost()
        root.default = static.File(share_path)
        root.addHost("localhost", static.File(share_path))

        root.putChild("upload", controllers.UploadResource())
        root.putChild("downloads", static.File(self.config.downloads_dir))

        # Setup ChannelSet
        channel_set = TwistedChannelSet(notify_connections=True)
#        services = TwistedChannel('services', wait_interval=90000)
        amf_channel = StreamingTwistedChannel('amf-streaming')
        channel_set.mapChannel(amf_channel)

        amf_polling = TwistedChannel('amf-polling')
        channel_set.mapChannel(amf_polling)

        amf_long_polling = TwistedChannel('amf-long-polling', wait_interval=90000)
        channel_set.mapChannel(amf_long_polling)


        # Map class aliases
        # These same aliases must be
        # registered in the client
        # with the registClassAlias function,
        # or the RemoteClass metadata tag.
        class_mapper = ClassDefMapper()
        class_mapper.mapClass(
            DynamicClassDef(Conversion,
                            'org.ufsoft.dac.conversions.Conversion')
        )

        # Set Channel options
        # We're going to use the same
        # Encoder and Decoder for all channels
        encoder = Encoder(use_collections=True, use_proxies=True,
                          class_def_mapper=class_mapper, use_legacy_xml=True)
        decoder = Decoder(class_def_mapper=class_mapper)
        for channel in channel_set:
            channel.endpoint.encoder = encoder
            channel.endpoint.decoder = decoder

        # Map service targets to controller methods
        cont_obj = controllers.Controller()
        rpc_channel = TwistedChannel('rpc')
        channel_set.mapChannel(rpc_channel)

        rpc_service = Service('WebServices')
        rpc_service.mapTarget(CallableTarget(cont_obj.raiseException, 'raiseException'))
        rpc_service.mapTarget(CallableTarget(cont_obj.get_process_queue, 'get_process_queue'))
        channel_set.service_mapper.mapService(rpc_service)        # Setup channels

        root.putChild('amf-streaming', amf_channel)
        root.putChild('amf-polling', amf_polling)
        root.putChild('amf-long-polling', amf_long_polling)
        root.putChild('rpc', rpc_channel)
        self.server = server.Site(root)
        self.channel_set = channel_set

        # Generate source code for mapped models
#        coder = CodeGenerator(indent='  ')
#        coder.generateFilesFromMapper(class_mapper, use_accessors=False,
#                                      packaged=True, constructor=False,
#                                      bindable=True, extends='Object',
#                                      dir=join(self.config.dir, '..', 'flex'))


        return self.server

    def setup_log(self):
        import sys
        global log
        log = logging.getLogger(__name__)
        amfast.log_debug = True
#        amfast.logger.addHandler(logging.getLogger('amfast').handlers[0])
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(logging.DEBUG)
        amfast.logger.addHandler(handler)


    def save_file(self, filename, filedata):
        output = join(self.config.uploads_dir, filename)
        f = open(output, 'wb')
        f.write(filedata)
        f.close()
        self.add_conversion(filename)

    def add_conversion(self, filename):
        conversion = Conversion(filename)
        self.process_queue.append(conversion)
        log.debug("Emitting Flex Object after adding conversion to queue")
        self.emit_flex_object(body=conversion, topic="conversions",
                              sub_topic='new')

    def check_process_queue(self):
        log.debug("Currently in process Queue: %s", len(self.process_queue))
#        process_queue = dict([(id(i), i) for i in self.process_queue])
#        self.emit_flex_object(body=process_queue, sub_topic='queue')
#        self.emit_flex_message(body="In Queue Now: %d" % len(self.process_queue))
        if self.processing:
            return

        for idx, item in enumerate(self.process_queue):
            if item.converted:
                continue
            if item.processing:
                break

            log.debug("Starting to convert %s", item)
            def finished(result):
                self.processing = False
            self.processing = True
            return deferToThread(self.process_queue[idx].process).addCallback(finished)

    def emit_flex_message(self, headers=None, body=None, topic='messages'):
        from amfast.remoting import flex_messages
        msg = flex_messages.AsyncMessage(headers=headers, body=body,
                                         destination=topic)
        self.channel_set.publishMessage(msg)

    def emit_flex_object(self, headers=None, body=None, topic='messages',
                         sub_topic=None):
        self.channel_set.publishObject(body, topic, sub_topic=sub_topic,
                                       headers=headers, ttl=30000)




app = Application()
