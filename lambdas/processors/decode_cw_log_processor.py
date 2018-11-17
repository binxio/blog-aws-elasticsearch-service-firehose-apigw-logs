from base64 import b64encode, b64decode
import json
import gzip

def decompress(data):
    return gzip.decompress(data)

def decode_record(data: dict) -> dict:
    x = decompress(b64decode(data['data']))
    return json.loads(x.decode('utf8'))

def handler(event, context):
    records = event['records']
    for record in records:
        record.pop('approximateArrivalTimestamp', None)
        decoded = decode_record(record)
        if decoded['messageType'] == "DATA_MESSAGE":
            print(f'processing: {json.dumps(decoded)}')
            event = decoded['logEvents'][0]
            event.update({'message': json.loads(event['message'])})
            print(f'indexing: {event}')
            msg = b64encode(bytes(json.dumps(event), 'utf-8')).decode('ascii')
            record.update({'data': msg})
            record.update({'result': 'Ok'}) # Ok, Dropped, ProcessingFailed
        else:
            print(f'dropping: {json.dumps(decoded)}')
            record.update({'result': 'Dropped'}) # Ok, Dropped, ProcessingFailed

    print(json.dumps(records))
    return {'records': records}
