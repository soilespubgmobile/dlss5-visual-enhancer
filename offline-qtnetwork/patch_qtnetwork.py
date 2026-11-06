"""Make QNetworkAccessManager refuse every non-local request (Qt 6.12.0).

Local file://, qrc: and data: URLs keep working. Every other request becomes a
reply without a backend, which Qt finishes asynchronously with
ProtocolUnknownError, so no socket, DNS lookup or proxy query is ever made.
"""
import sys
from pathlib import Path

path = Path(sys.argv[1]) / 'src/network/access/qnetworkaccessmanager.cpp'
text = path.read_text(encoding='utf-8')
anchor = '    QNetworkRequest request = req;\n    auto h = request.headers();\n'
assert text.count(anchor) == 1, 'anchor not found exactly once'
patch = '''    // VE-OFFLINE: every non-local request fails here, before any network access.
    if (!isLocalFile) {
        QNetworkReplyImpl *offlineReply = new QNetworkReplyImpl(this);
        QNetworkReplyImplPrivate *offlinePriv = offlineReply->d_func();
        offlinePriv->manager = this;
        offlinePriv->backend = nullptr;
        offlinePriv->setup(op, req, outgoingData);
        return offlineReply;
    }
'''
path.write_text(text.replace(anchor, patch + anchor), encoding='utf-8')
print('patched', path)
