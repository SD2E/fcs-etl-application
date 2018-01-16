from SPARQLWrapper import SPARQLWrapper, JSON
import json
from config import settings
import urllib2

class ExperimentalCondition:
    def __init__(self,host,uri):
        self.host = host
        self.uri = uri

        try:
            raise urllib2.URLError('Testing')
            sparql = SPARQLWrapper(host)

            sparql.setQuery("""
                    select distinct ?subject ?label ?num  where {{
                    ?subject ?predicate <{}> .
                    ?subject <http://purl.org/dc/terms/title>  ?label .
                    FILTER(STRENDS(STR(?label), "_measure")) .
                    ?subject <http://www.ontology-of-units-of-measure.org/resource/om-2#hasNumericalValue> ?num .
                    }}
            """.format(uri))

            sparql.setReturnFormat(JSON)
            results = sparql.query().convert()

            self.conditions = {}

            for result in results["results"]["bindings"]:
                self.conditions[result["label"]["value"]] = result["num"]["value"]

            sparql.setQuery("""
                            select distinct ?plasmid where {{
                             <{}> <http://sd2e.org#plasmid> ?plasmid.
                            }}
                    """.format(uri))

            sparql.setReturnFormat(JSON)
            results = sparql.query().convert()

            self.conditions['plasmids'] = []
            for result in results["results"]["bindings"]:
                self.conditions["plasmids"].append(result["plasmid"]["value"])

        except urllib2.URLError as e:
            print 'Warning, cound not collect to {}'.format(host)
            self.conditions = {}
            self.conditions['uri'] = uri

    def to_string(self,keys,seperator=","):
        return seperator.join(map(lambda k: self.conditions[k], keys))

    def __str__(self):
        return json.dumps(self.conditions)


# testing method
if __name__ == '__main__':
    #e = ExperimentalCondition("http://hub.sd2e.org:8890/sparql","http://hub.sd2e.org/user/nroehner/rule30_conditions/pAN3928_pAN4036_system_5_0_0/1.0.0")
    e = ExperimentalCondition(settings.sparql.host, settings.sparql.uri)

