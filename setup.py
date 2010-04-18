#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: sw=4 ts=4 fenc=utf-8 et
# ==============================================================================
# Copyright © 2009 UfSoft.org - Pedro Algarvio <ufs@ufsoft.org>
#
# License: BSD - Please view the LICENSE file for additional information.
# ==============================================================================

from setuptools import setup, find_packages

import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'python'))

import baca

setup(name=baca.__package__,
      version=baca.__version__,
      author=baca.__author__,
      author_email=baca.__email__,
      url=baca.__url__,
      download_url='http://python.org/pypi/%s' % baca.__package__,
      description=baca.__summary__,
      long_description=baca.__description__,
      license=baca.__license__,
      platforms="OS Independent - Anywhere Twisted and GStremaer is known to run.",
      keywords = "Twisted Gstreamer Flex Conversion",
      packages = find_packages('python'),
      package_dir = {'':'python'},
      message_extractors = {
        'python': [
            ('**.py', 'python', None)
        ],
        'flex': [
            ('**.as', 'baca.utils.extract:extract_actionscript', None),
            ('**.mxml', 'baca.utils.extract:extract_mxml', {
                'attrs': [
                    u'label', u'text', u'title', u'headerText', u'prompt']}),
        ]
      },
      entry_points = """
      [console_scripts]
      baca-daemon = baca.bootstrap:daemon

      [distutils.commands]
      compile = babel.messages.frontend:compile_catalog
      extract = babel.messages.frontend:extract_messages
         init = babel.messages.frontend:init_catalog
       update = babel.messages.frontend:update_catalog
      """,
      classifiers=[
          'Development Status :: 5 - Alpha',
          'Environment :: Web Environment',
          'Intended Audience :: System Administrators',
          'License :: OSI Approved :: BSD License',
          'Operating System :: OS Independent',
          'Programming Language :: Python',
          'Topic :: Utilities',
          'Topic :: Internet :: WWW/HTTP',
          'Topic :: Internet :: WWW/HTTP :: Dynamic Content',
      ]
)
