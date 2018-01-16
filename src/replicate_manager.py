

class ReplicateManager:
    def __init__(self):
        self.per_condition_string = {}

    def get_replicate(self,string):

        if not string in self.per_condition_string:
            self.per_condition_string[string] = -1

        self.per_condition_string[string] += 1
        return self.per_condition_string[string]
