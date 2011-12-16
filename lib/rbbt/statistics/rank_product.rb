require 'rbbt/tsv'

module RankProduct
  def self.score(gene_ranks, signature_sizes)
    scores = {}
    log_sizes = signature_sizes.collect{|size| Math::log(size)}
    gene_ranks.each{|gene, positions|
      scores[gene] = positions.zip(log_sizes).
        collect{|p| Math::log(p[0]) - p[1]}.    # Take log and substract from size (normalize)
        inject(0){|acc, v| acc += v  }
    }
    scores
  end

  def self.permutations(num_signatures, num = 1000)
    scores = []
    num.times{
       value = 0
       num_signatures.times{|size_and_log| 
         value += Math::log(rand)
       } 
       scores << value
    }
    scores
  end

  def self.permutations_full(signature_sizes)
    gene_ranks = {}
    signature_sizes.each{|size|
      (1..size).to_a.shuffle.each_with_index{|gene, pos|
        gene_ranks[gene] ||= []
        gene_ranks[gene] << pos + 1
      }
    }
    gene_ranks.delete_if{|code, positions| positions.length != signature_sizes.length}

    scores = score(gene_ranks, signature_sizes)
    scores.values
  end
end

module TSV
  def rank_product(fields, reverse = false, &block)
    tsv = self.slice(fields)

    if block_given?
      scores = fields.collect{|field| tsv.sort_by(field, true, &block)}
    else
      scores = fields.collect{|field| tsv.sort_by(field, true){|gene,values| tsv.type == :double ? values.first.to_f : value.to_f}}
    end
    positions = {}
    
    if reverse
      size = self.size
      tsv.keys.each do |entity|
        positions[entity] = scores.collect{|list| size - list.index(entity)}
      end
    else
      tsv.keys.each do |entity|
        positions[entity] = scores.collect{|list| list.index(entity) + 1}
      end
    end

    score = RankProduct.score(positions, fields.collect{ tsv.size })

    score
  end
end
